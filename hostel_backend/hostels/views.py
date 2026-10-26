from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from accounts.permissions import IsSuperAdmin

from .models import Hostel
from .serializers import HostelSerializer


class HostelViewSet(viewsets.ModelViewSet):
    queryset = Hostel.objects.all().order_by('name')
    serializer_class = HostelSerializer

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [IsSuperAdmin()]
        return [IsAuthenticated()]

