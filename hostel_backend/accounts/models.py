from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """
    Base login table for every role in the system.
    Role-specific data (hostel, room, shift, etc.) lives in the
    Warden / Student / SecurityGuard models via a OneToOneField to this.
    """

    class Role(models.TextChoices):
        SUPER_ADMIN = 'admin', 'Super Admin'
        WARDEN = 'warden', 'Warden'
        GUARD = 'guard', 'Security Guard'
        STUDENT = 'student', 'Student'

    role = models.CharField(max_length=10, choices=Role.choices)

    # True until the user changes their temporary, admin/warden-issued
    # password for the first time. The Flutter app should read this from
    # the login response and force the "set your password" screen.
    must_change_password = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"
