from rest_framework import serializers
from .models import EntryExit, EntryExitRequest


class EntryExitSerializer(serializers.ModelSerializer):
    class Meta:
        model = EntryExit
        fields = '__all__'


class EntryExitRequestSerializer(serializers.ModelSerializer):
    student_name = serializers.CharField(
        source='student.user.get_full_name',
        read_only=True
    )

    enrollment_no = serializers.CharField(
        source='student.enrollment_no',
        read_only=True
    )

    room_no = serializers.CharField(
        source='student.room_no',
        read_only=True
    )

    decided_by_name = serializers.SerializerMethodField()
    entry_time = serializers.SerializerMethodField()

    def get_decided_by_name(self, obj):
        if obj.decided_by:
            return obj.decided_by.get_full_name() or obj.decided_by.username
        return None

    def get_entry_time(self, obj):
        if obj.request_type != 'ENTRY' or obj.status != 'APPROVED':
            return None

        if obj.entry_time:
            return obj.entry_time

        log = EntryExit.objects.filter(
            student=obj.student,
            status='IN',
            entry_time__isnull=False
        ).order_by('-entry_time').first()

        return log.entry_time if log else None

    class Meta:
        model = EntryExitRequest
        fields = [
            'id',
            'student',
            'student_name',
            'enrollment_no',
            'room_no',
            'request_type',
            'destination',
            'expected_return_time',
            'request_time',
            'status',
            'entry_time',
            'rejection_reason',
            'decided_by',
            'decided_by_name',
        ]
        read_only_fields = [
            'id',
            'student',
            'student_name',
            'enrollment_no',
            'room_no',
            'request_time',
            'status',
            'entry_time',
            'rejection_reason',
            'decided_by',
            'decided_by_name',
        ]
