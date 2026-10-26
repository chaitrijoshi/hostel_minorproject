from django.conf import settings
from django.db import models

from hostels.models import Hostel


class Student(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='student_profile'
    )
    hostel = models.ForeignKey(Hostel, on_delete=models.CASCADE, related_name='students')
    enrollment_no = models.CharField(max_length=50, unique=True)
    room_no = models.CharField(max_length=20)
    phone = models.CharField(max_length=15, blank=True)
    parent_contact = models.CharField(max_length=15, blank=True)

    def __str__(self):
        return f"{self.user.get_full_name() or self.user.username} ({self.enrollment_no})"
