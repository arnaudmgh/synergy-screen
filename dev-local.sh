#!/bin/bash
# Local development script
cd hugo-site
hugo server --baseURL "http://localhost:1313" --bind "0.0.0.0" --port 1313
