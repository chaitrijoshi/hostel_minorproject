from django.contrib import admin
from django.urls import path, include
urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('accounts.urls')),
    path('api/hostels/', include('hostels.urls')),
    path('api/wardens/', include('wardens.urls')),
    path('api/students/', include('students.urls')),
    path('api/guards/', include('security.urls')),
    path('api/entry-exit/', include('entry_exit.urls')),
    path('api/visitors/', include('visitors.urls')),
    path('api/notifications/', include('notifications.urls')),
]
