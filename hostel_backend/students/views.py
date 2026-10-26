from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from accounts.permissions import IsWarden

from .models import Student
from .serializers import StudentSerializer


class StudentViewSet(viewsets.ModelViewSet):
    serializer_class = StudentSerializer

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [IsWarden()]
        return [IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user
        qs = Student.objects.select_related('user', 'hostel').order_by('room_no')

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
        # a warden can only ever create students for their own hostel
        warden = self.request.user.warden_profile
        serializer.save(hostel=warden.hostel)
