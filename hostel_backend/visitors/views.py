from django.utils import timezone
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from accounts.permissions import IsGuard

from .models import Visitor
from .serializers import VisitorSerializer


class VisitorViewSet(viewsets.ModelViewSet):
    serializer_class = VisitorSerializer
    http_method_names = ['get', 'post', 'head', 'options']

    def get_permissions(self):
        if self.action in ('create', 'mark_exit'):
            return [IsGuard()]
        return [IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user
        qs = Visitor.objects.select_related('student__user', 'guard__user')

        if user.role == 'admin':
            return qs
        if user.role == 'warden':
            return qs.filter(student__hostel=user.warden_profile.hostel)
        if user.role == 'guard':
            return qs.filter(guard=user.guard_profile)
        if user.role == 'student':
            return qs.filter(student=user.student_profile)
        return qs.none()

    @action(detail=True, methods=['post'])
    def mark_exit(self, request, pk=None):
        visitor = self.get_object()
        visitor.exit_time = timezone.now()
        visitor.status = Visitor.Status.OUT
        visitor.save()
        return Response(VisitorSerializer(visitor).data)
