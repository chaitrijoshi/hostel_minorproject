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

    entry_time = serializers.SerializerMethodField()

    def get_entry_time(self, obj):
        if obj.request_type != 'ENTRY' or obj.status != 'APPROVED':
            return None

        log = EntryExit.objects.filter(
            student=obj.student,
            status='IN',
            entry_time__isnull=False
        ).order_by('-entry_time').first()

        if log:
            return log.entry_time

        return None

    class Meta:
        model = EntryExitRequest
        fields = [
            'id',
            'student',
            'student_name',
            'request_type',
            'destination',
            'expected_return_time',
            'request_time',
            'status',
            'entry_time',
        ]

        read_only_fields = [
            'id',
            'student',
            'student_name',
            'request_time',
            'status',
            'entry_time',
        ]
