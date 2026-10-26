from django.db import models


class Visitor(models.Model):
    class Status(models.TextChoices):
        IN = 'IN', 'In'
        OUT = 'OUT', 'Out'

    name = models.CharField(max_length=100)
    phone = models.CharField(max_length=15)
    purpose = models.CharField(max_length=200, blank=True)
    student = models.ForeignKey('students.Student', on_delete=models.CASCADE, related_name='visitors')
    guard = models.ForeignKey(
        'security.SecurityGuard', on_delete=models.SET_NULL, null=True, related_name='visitor_logs'
    )
    entry_time = models.DateTimeField(null=True, blank=True)
    exit_time = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=3, choices=Status.choices, default=Status.IN)

    class Meta:
        ordering = ['-entry_time']

    def __str__(self):
        return f"{self.name} visiting {self.student}"
