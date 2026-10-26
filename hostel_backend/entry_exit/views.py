
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


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def entry_exit_logs(request):

    if request.method == 'GET':
        logs = EntryExit.objects.all()
        serializer = EntryExitSerializer(logs, many=True)
        return Response(serializer.data)

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

    entry_exit_request = EntryExitRequest.objects.create(
        student=student,
        request_type=request_type,
        destination=destination,
        expected_return_time=expected_return_time
    )

    serializer = EntryExitRequestSerializer(entry_exit_request)

    return Response(
        serializer.data,
        status=status.HTTP_201_CREATED
    )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def pending_entry_exit_requests(request):

    requests = EntryExitRequest.objects.filter(status='PENDING')

    serializer = EntryExitRequestSerializer(requests, many=True)

    return Response(serializer.data)


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

    requests = EntryExitRequest.objects.filter(student=student)

    serializer = EntryExitRequestSerializer(requests, many=True)

    return Response(serializer.data)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_entry_exit_request(request, request_id):

    try:
        entry_exit_request = EntryExitRequest.objects.get(id=request_id)
    except EntryExitRequest.DoesNotExist:
        return Response(
            {'error': 'Request not found.'},
            status=status.HTTP_404_NOT_FOUND
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

    if new_status == 'APPROVED':

        try:
            guard = request.user.guard_profile
        except AttributeError:
            return Response(
                {'error': 'Security guard profile not found.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if entry_exit_request.request_type == 'ENTRY':

            actual_time = timezone.now()

            EntryExit.objects.create(
                student=entry_exit_request.student,
                guard=guard,
                entry_time=actual_time,
                status='IN'
            )

            entry_exit_request.entry_time = actual_time
            entry_exit_request.save(update_fields=['entry_time'])
        elif entry_exit_request.request_type == 'EXIT':

            EntryExit.objects.create(
                student=entry_exit_request.student,
                guard=guard,
                exit_time=timezone.now(),
                status='OUT'
            )

    entry_exit_request.status = new_status
    entry_exit_request.save()

    serializer = EntryExitRequestSerializer(entry_exit_request)

    return Response(serializer.data)
