
from django.db import models


class EntryExit(models.Model):

    class Status(models.TextChoices):
        IN = 'IN', 'In'
        OUT = 'OUT', 'Out'

    student = models.ForeignKey(
        'students.Student',
        on_delete=models.CASCADE,
        related_name='logs'
    )

    guard = models.ForeignKey(
        'security.SecurityGuard',
        on_delete=models.SET_NULL,
        null=True,
        related_name='logs'
    )

    entry_time = models.DateTimeField(
        null=True,
        blank=True
    )

    exit_time = models.DateTimeField(
        null=True,
        blank=True
    )

    status = models.CharField(
        max_length=3,
        choices=Status.choices
    )

    remarks = models.TextField(blank=True)

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return (
            f"{self.student} — {self.status} "
            f"@ {self.created_at:%Y-%m-%d %H:%M}"
        )


class EntryExitRequest(models.Model):

    REQUEST_TYPES = [
        ('EXIT', 'Exit'),
        ('ENTRY', 'Entry'),
    ]

    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('APPROVED', 'Approved'),
        ('REJECTED', 'Rejected'),
    ]

    student = models.ForeignKey(
        'students.Student',
        on_delete=models.CASCADE,
        related_name='entry_exit_requests'
    )

    request_type = models.CharField(
        max_length=5,
        choices=REQUEST_TYPES
    )

    destination = models.CharField(
        max_length=255,
        blank=True
    )

    expected_return_time = models.DateTimeField(
        null=True,
        blank=True
    )

    # Actual time when the guard approves the ENTRY request
    entry_time = models.DateTimeField(
        null=True,
        blank=True
    )

    request_time = models.DateTimeField(
        auto_now_add=True
    )

    status = models.CharField(
        max_length=10,
        choices=STATUS_CHOICES,
        default='PENDING'
    )

    class Meta:
        ordering = ['-request_time']

    def __str__(self):
        return (
            f"{self.student} - "
            f"{self.request_type} - {self.status}"
        )
