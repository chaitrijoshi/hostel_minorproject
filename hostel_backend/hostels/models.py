from django.db import models


class Hostel(models.Model):
    name = models.CharField(max_length=100)
    address = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
class Entry_Exit_Log(models.Model):
    destination =models.CharField( max_length=50)
    date=models.DateField()
    def __str__(self):
        return self.name
