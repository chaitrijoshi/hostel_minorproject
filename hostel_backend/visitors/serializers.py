from django.utils import timezone
from rest_framework import serializers

from students.models import Student

from .models import Visitor


class VisitorSerializer(serializers.ModelSerializer):
    enrollment_no = serializers.CharField(write_only=True)  # the student being visited

    student_name = serializers.CharField(source='student.user.get_full_name', read_only=True)
    guard_name = serializers.CharField(source='guard.user.get_full_name', read_only=True)

    class Meta:
        model = Visitor
        fields = [
            'id', 'name', 'phone', 'purpose', 'enrollment_no', 'student', 'student_name',
            'guard', 'guard_name', 'entry_time', 'exit_time', 'status',
        ]
        read_only_fields = ['student', 'guard', 'entry_time', 'exit_time']

    def validate_enrollment_no(self, value):
        guard = self.context['request'].user.guard_profile
        try:
            student = Student.objects.get(enrollment_no=value, hostel=guard.hostel)
        except Student.DoesNotExist:
            raise serializers.ValidationError(
                "No student with this enrollment number in your hostel."
            )
        self._student = student
        return value

    def create(self, validated_data):
        validated_data.pop('enrollment_no')
        guard = self.context['request'].user.guard_profile
        return Visitor.objects.create(
            student=self._student,
            guard=guard,
            entry_time=timezone.now(),
            status=Visitor.Status.IN,
            **validated_data,
        )
