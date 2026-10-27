import os
import json
from urllib.parse import urlencode
from urllib.request import urlopen
from urllib.error import HTTPError, URLError

from django.utils import timezone

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from .models import EntryExit, EntryExitRequest
from .serializers import (
    EntryExitSerializer,
    EntryExitRequestSerializer,
)


def has_unreturned_exit(student):
    last_request = EntryExitRequest.objects.filter(
        student=student,
        status='APPROVED',
        request_type__in=['EXIT', 'ENTRY']
    ).order_by('-id').first()

    return (
        last_request is not None
        and last_request.request_type == 'EXIT'
    )


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def entry_exit_logs(request):

    if request.method == 'GET':
        logs = EntryExit.objects.all()
        return Response(
            EntryExitSerializer(logs, many=True).data
        )

    student_id = request.data.get('student')
    guard_id = request.data.get('guard')
    log_status = request.data.get('status')

    if log_status not in ['IN', 'OUT']:
        return Response(
            {'error': 'Status must be IN or OUT.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    log = EntryExit.objects.create(
        student_id=student_id,
        guard_id=guard_id,
        entry_time=timezone.now() if log_status == 'IN' else None,
        exit_time=timezone.now() if log_status == 'OUT' else None,
        status=log_status,
        remarks=request.data.get('remarks', '')
    )

    return Response(
        EntryExitSerializer(log).data,
        status=status.HTTP_201_CREATED
    )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_entry_exit_request(request):

    try:
        student = request.user.student_profile
    except AttributeError:
        return Response(
            {'error': 'Student profile not found.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    request_type = request.data.get('request_type')
    destination = request.data.get('destination', '')
    expected_return_time = request.data.get('expected_return_time')

    if request_type not in ['EXIT', 'ENTRY']:
        return Response(
            {'error': 'Request type must be EXIT or ENTRY.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    active_exit = has_unreturned_exit(student)

    if request_type == 'EXIT':

        if active_exit:
            return Response(
                {
                    'error': (
                        'You already have an approved exit. '
                        'Complete your entry request before '
                        'requesting another exit.'
                    )
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        pending_exit = EntryExitRequest.objects.filter(
            student=student,
            request_type='EXIT',
            status='PENDING'
        ).exists()

        if pending_exit:
            return Response(
                {
                    'error': (
                        'You already have a pending exit request. '
                        'Wait for the guard to process it.'
                    )
                },
                status=status.HTTP_400_BAD_REQUEST
            )

    if request_type == 'ENTRY':

        if not active_exit:
            return Response(
                {
                    'error': (
                        'You must have an approved exit before '
                        'requesting entry.'
                    )
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        pending_entry = EntryExitRequest.objects.filter(
            student=student,
            request_type='ENTRY',
            status='PENDING'
        ).exists()

        if pending_entry:
            return Response(
                {
                    'error': (
                        'You already have a pending entry request. '
                        'Wait for the guard to process it.'
                    )
                },
                status=status.HTTP_400_BAD_REQUEST
            )

    entry_exit_request = EntryExitRequest.objects.create(
        student=student,
        request_type=request_type,
        destination=destination,
        expected_return_time=expected_return_time
    )

    return Response(
        EntryExitRequestSerializer(entry_exit_request).data,
        status=status.HTTP_201_CREATED
    )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def pending_entry_exit_requests(request):

    requests = EntryExitRequest.objects.filter(
        status='PENDING'
    )

    return Response(
        EntryExitRequestSerializer(requests, many=True).data
    )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_entry_exit_requests(request):

    try:
        student = request.user.student_profile
    except AttributeError:
        return Response(
            {'error': 'Student profile not found.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    requests = EntryExitRequest.objects.filter(
        student=student
    )

    return Response(
        EntryExitRequestSerializer(requests, many=True).data
    )


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_entry_exit_request(request, request_id):

    try:
        entry_exit_request = EntryExitRequest.objects.get(
            id=request_id
        )
    except EntryExitRequest.DoesNotExist:
        return Response(
            {'error': 'Request not found.'},
            status=status.HTTP_404_NOT_FOUND
        )

    try:
        guard = request.user.guard_profile
    except AttributeError:
        return Response(
            {'error': 'Security guard profile not found.'},
            status=status.HTTP_403_FORBIDDEN
        )

    new_status = request.data.get('status')

    if new_status not in ['APPROVED', 'REJECTED']:
        return Response(
            {'error': 'Status must be APPROVED or REJECTED.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    if entry_exit_request.status != 'PENDING':
        return Response(
            {'error': 'This request has already been processed.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    student = entry_exit_request.student

    if new_status == 'REJECTED':

        rejection_reason = request.data.get(
            'rejection_reason', ''
        ).strip()

        if not rejection_reason:
            return Response(
                {'error': 'Please enter a rejection reason.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        entry_exit_request.rejection_reason = rejection_reason

    elif new_status == 'APPROVED':

        actual_time = timezone.now()

        if entry_exit_request.request_type == 'EXIT':

            if has_unreturned_exit(student):
                return Response(
                    {
                        'error': (
                            'This student already has an '
                            'unreturned approved exit.'
                        )
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )

            EntryExit.objects.create(
                student=student,
                guard=guard,
                exit_time=actual_time,
                status='OUT'
            )

        elif entry_exit_request.request_type == 'ENTRY':

            if not has_unreturned_exit(student):
                return Response(
                    {
                        'error': (
                            'This student does not have an '
                            'active approved exit.'
                        )
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )

            EntryExit.objects.create(
                student=student,
                guard=guard,
                entry_time=actual_time,
                status='IN'
            )

            entry_exit_request.entry_time = actual_time

    # Save the guard's decision.
    entry_exit_request.status = new_status
    entry_exit_request.decided_by = request.user
    entry_exit_request.save()

    return Response(
        EntryExitRequestSerializer(entry_exit_request).data,
        status=status.HTTP_200_OK
    )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def request_reports(request):

    user = request.user
    role = getattr(user, 'role', None)

    requests = EntryExitRequest.objects.select_related(
        'student__user',
        'student__hostel',
        'decided_by'
    ).all()

    if role == 'student':
        try:
            student = user.student_profile
        except AttributeError:
            return Response(
                {'error': 'Student profile not found.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        requests = requests.filter(student=student)

    elif role == 'guard':
        requests = requests.filter(decided_by=user)

    elif role == 'warden':
        try:
            warden = user.warden_profile
        except AttributeError:
            return Response(
                {'error': 'Warden profile not found.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        requests = requests.filter(student__hostel=warden.hostel)

    elif role != 'admin':
        return Response(
            {'error': 'You do not have permission to view reports.'},
            status=status.HTTP_403_FORBIDDEN
        )

    serializer = EntryExitRequestSerializer(requests, many=True)
    return Response(serializer.data)


# GEOAPIFY DESTINATION AUTOCOMPLETE

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def destination_suggestions(request):

    text = request.query_params.get('text', '').strip()

    if len(text) < 3:
        return Response({'results': []})

    api_key = os.environ.get('GEOAPIFY_API_KEY')

    if not api_key:
        return Response(
            {'error': 'Geoapify API key is not configured.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

    params = urlencode({
        'text': text,
        'format': 'json',
        'limit': 5,
        'filter': 'countrycode:in',
        'apiKey': api_key,
    })

    url = (
        'https://api.geoapify.com/v1/geocode/autocomplete?'
        + params
    )

    try:
        with urlopen(url, timeout=10) as response:
            data = json.loads(
                response.read().decode('utf-8')
            )

        results = [
            {
                'name': item.get('name', ''),
                'formatted': item.get('formatted', ''),
            }
            for item in data.get('results', [])
        ]

        return Response({'results': results})

    except (HTTPError, URLError, TimeoutError, ValueError):
        return Response(
            {'error': 'Unable to fetch destination suggestions.'},
            status=status.HTTP_502_BAD_GATEWAY
        )