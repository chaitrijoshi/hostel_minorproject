
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import status

from accounts.permissions import IsWarden

from .models import Student
from .serializers import StudentSerializer


class StudentViewSet(viewsets.ModelViewSet):
    serializer_class = StudentSerializer

    def get_permissions(self):
        if self.action in (
            'create',
            'update',
            'partial_update',
            'destroy',
            'change_active_status',
        ):
            return [IsWarden()]
        return [IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user

        qs = Student.objects.select_related(
            'user', 'hostel'
        ).order_by('room_no')

        if user.role == 'admin':
            return qs

        if user.role == 'warden':
            return qs.filter(hostel=user.warden_profile.hostel)

        if user.role == 'guard':
            return qs.filter(hostel=user.guard_profile.hostel)

        if user.role == 'student':
            return qs.filter(user=user)

        return qs.none()

    def perform_create(self, serializer):
        # A warden can create students only for their own hostel.
        warden = self.request.user.warden_profile
        serializer.save(hostel=warden.hostel)

    @action(
        detail=True,
        methods=['patch'],
        url_path='change-active-status',
        permission_classes=[IsWarden]
    )
    def change_active_status(self, request, pk=None):
        student = self.get_object()

        is_active = request.data.get('is_active')

        if not isinstance(is_active, bool):
            return Response(
                {
                    'error': 'Send is_active as true or false.'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        student.is_active = is_active
        student.save(update_fields=['is_active'])

        # Also deactivate the associated login account.
        student.user.is_active = is_active
        student.user.save(update_fields=['is_active'])

        return Response(
            {
                'message': (
                    'Student activated successfully.'
                    if is_active
                    else 'Student deactivated successfully.'
                ),
                'student_id': student.id,
                'is_active': student.is_active,
            },
            status=status.HTTP_200_OK
        )
