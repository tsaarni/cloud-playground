#!/bin/env python3

import argparse
import json
import logging
import os
import time
import traceback

from kubernetes import client, config, watch

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s.%(msecs)03d %(levelname)s: %(message)s",
    datefmt="%H:%M:%S",
)

group = "projectcontour.io"
version = "v1"
plural = "httpproxies"
namespace = "default"


def list_resources(api, resource_version=None):
    results = api.list_namespaced_custom_object(group, version, namespace, plural, resource_version=resource_version)
    logging.info(json.dumps(results, indent=2))


def watch_resources(api, resource_version=None, timeout=None):
    w = watch.Watch()
    try:
        for event in w.stream(
            api.list_namespaced_custom_object,
            group=group,
            version=version,
            namespace=namespace,
            plural=plural,
            allow_watch_bookmarks=True,
            resource_version=resource_version,
            timeout_seconds=timeout,
        ):
            logging.info("Received event\n" + json.dumps(event, indent=2))
    except Exception as e:
        logging.error(f"Error during watch: {e}")
        logging.debug(traceback.format_exc())
    finally:
        w.stop()


def main():
    parser = argparse.ArgumentParser(description="List and watch Kubernetes resources.")
    parser.add_argument("operation", choices=["list", "watch"], help="Operation to run: list or watch")
    parser.add_argument("--resource-version", type=str, help="Resource version to start watching from.")
    parser.add_argument("--sslkeylogfile", type=str, help="Path to SSL key log file for Wireshark.")
    parser.add_argument("--debug", action="store_true", help="Enable debug logging.")
    parser.add_argument("--timeout", type=int, help="Timeout for the watch operation in seconds.")
    args = parser.parse_args()

    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)

    if args.sslkeylogfile:
        logging.info(f"Setting SSLKEYLOGFILE to {args.sslkeylogfile}")
        os.environ["SSLKEYLOGFILE"] = args.sslkeylogfile

    config.load_kube_config()
    api = client.CustomObjectsApi()

    if args.operation == "list":
        list_resources(api, args.resource_version)
    elif args.operation == "watch":
        watch_resources(api, args.resource_version, args.timeout)
    else:
        logging.error("Invalid mode. Choose 'list' or 'watch'.")


if __name__ == "__main__":
    start_time = time.time()
    main()
    end_time = time.time()
    logging.info(f"Execution time: {end_time - start_time} seconds")
