from django.conf import settings
from django.db import models

from hostels.models import Hostel


class SecurityGuard(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='guard_profile'
    )
    hostel = models.ForeignKey(Hostel, on_delete=models.CASCADE, related_name='guards')
    shift_time = models.CharField(max_length=50, blank=True)

    def __str__(self):
        return f"{self.user.get_full_name() or self.user.username} — {self.hostel.name}"
