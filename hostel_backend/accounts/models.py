from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):

    class Role(models.TextChoices):
        SUPER_ADMIN = 'admin', 'Super Admin'
        WARDEN = 'warden', 'Warden'
        GUARD = 'guard', 'Security Guard'
        STUDENT = 'student', 'Student'

    role = models.CharField(max_length=10, choices=Role.choices)
    must_change_password = models.BooleanField(default=True)
    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"
