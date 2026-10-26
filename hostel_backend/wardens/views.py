from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from accounts.permissions import IsSuperAdmin

from .models import Warden
from .serializers import WardenSerializer


class WardenViewSet(viewsets.ModelViewSet):
    """
    Only the super admin creates, edits, or removes warden accounts.
    This is the only way a Warden login gets created — matching
    'admin creates hostel -> admin creates warden' in the UI flow.
    """
    queryset = Warden.objects.select_related('user', 'hostel').order_by('hostel__name')
    serializer_class = WardenSerializer
    permission_classes = [IsSuperAdmin]
