"""
Websocket routing configuration for the djac-app project.

It exposes the `websocket_urlpatterns` list, a list of url patterns to be used
for deployment.

See Also
--------
https://channels.readthedocs.io/en/stable/topics/routing.html
"""

from typing import Any, List

import academic_community.routing
from django.urls import path  # noqa: F401

websocket_urlpatterns: List[
    Any
] = academic_community.routing.websocket_urlpatterns + [
    # django project specific routes
]
