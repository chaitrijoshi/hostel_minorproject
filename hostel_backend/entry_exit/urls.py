from django.urls import path

from .views import (
    entry_exit_logs,
    destination_suggestions,
    create_entry_exit_request,
    pending_entry_exit_requests,
    my_entry_exit_requests,
    update_entry_exit_request,
     request_reports,
)


urlpatterns = [

    # Existing entry/exit logs
    path(
        '',
        entry_exit_logs,
        name='entry-exit-logs'
    ),

    # Student creates a request
    path(
        'requests/create/',
        create_entry_exit_request,
        name='create-entry-exit-request'
    ),

    # Guard sees pending requests
    path(
        'requests/pending/',
        pending_entry_exit_requests,
        name='pending-entry-exit-requests'
    ),

    # Student sees own requests
    path(
        'requests/my/',
        my_entry_exit_requests,
        name='my-entry-exit-requests'
    ),
        path(
        'requests/report/',
        request_reports,
        name='request-reports'
    ),

    # Guard approves/rejects
    path(
        'requests/<int:request_id>/',
        update_entry_exit_request,
        name='update-entry-exit-request'
    ),

    path(
    'destination-suggestions/',
    destination_suggestions,
    name='destination_suggestions'
    ),
]