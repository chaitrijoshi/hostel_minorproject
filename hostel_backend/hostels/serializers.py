from rest_framework import serializers

from .models import Hostel


class HostelSerializer(serializers.ModelSerializer):
    warden_count = serializers.IntegerField(source='wardens.count', read_only=True)
    student_count = serializers.IntegerField(source='students.count', read_only=True)
    guard_count = serializers.IntegerField(source='guards.count', read_only=True)

    class Meta:
        model = Hostel
        fields = ['id', 'name', 'address', 'created_at', 'warden_count', 'student_count', 'guard_count']
