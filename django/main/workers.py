"""
Websocket routing configuration for the djac-app project.

It exposes the `workers` dictionary, a mapping from worker name
consumer to be used by channels `ChannelNameRouter`.

See Also
--------
https://channels.readthedocs.io/en/stable/topics/worker.html#receiving-and-consumers
"""
from typing import Any, Dict

from academic_community.notifications.consumers import NotificationWorker

workers: Dict[str, Any] = {"notification-worker": NotificationWorker.as_asgi()}
