from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from accounts.permissions import IsWarden

from .models import SecurityGuard
from .serializers import SecurityGuardSerializer


class SecurityGuardViewSet(viewsets.ModelViewSet):
    serializer_class = SecurityGuardSerializer

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [IsWarden()]
        return [IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user
        qs = SecurityGuard.objects.select_related('user', 'hostel')

        if user.role == 'admin':
            return qs
        if user.role == 'warden':
            return qs.filter(hostel=user.warden_profile.hostel)
        if user.role == 'guard':
            return qs.filter(user=user)
        return qs.none()

    def perform_create(self, serializer):
        warden = self.request.user.warden_profile
        serializer.save(hostel=warden.hostel)
