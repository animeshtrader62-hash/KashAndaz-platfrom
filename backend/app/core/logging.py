import logging
import structlog


def configure_logging(log_level: str) -> None:
    logging.basicConfig(
        level=log_level,
        format="%(message)s",
    )
    structlog.configure(
        wrapper_class=structlog.make_filtering_bound_logger(
            getattr(logging, log_level.upper(), logging.INFO)
        ),
        processors=[
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.JSONRenderer(),
        ],
    )
