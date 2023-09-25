"""
ASGI config for the djac-app project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/3.2/howto/deployment/asgi/
"""

# isort: off
import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "main.settings")
# isort: on

from channels.auth import AuthMiddlewareStack
from channels.routing import ChannelNameRouter, ProtocolTypeRouter, URLRouter
from channels.security.websocket import AllowedHostsOriginValidator
from channels.sessions import SessionMiddlewareStack
from django.core.asgi import get_asgi_application

from main.routing import websocket_urlpatterns
from main.workers import workers

application = ProtocolTypeRouter(
    {
        "http": get_asgi_application(),
        "websocket": AllowedHostsOriginValidator(
            SessionMiddlewareStack(
                AuthMiddlewareStack(URLRouter(websocket_urlpatterns))
            )
        ),
        "channel": ChannelNameRouter(workers),
    }
)
