#!/bin/bash

HEALTH_CHECK_STATE_FILE="/tmp/health_check_passed"

if [ -z "$1" ]; then TYPE="all"; else TYPE=$1; shift; fi

case $TYPE in
    health)
        if [ -f "$HEALTH_CHECK_STATE_FILE" ]; then
            message 42 'SUCCESS' "Health check already passed previously. Skipping."
            exit 0
        fi

        message "Running health check .."
        PORT=$(grep -A 1 'ports:' docker-compose.yaml | awk -F ':' 'NR==2 {print $2}' | tr -d ' ')
        if [ -z "$PORT" ]; then
            message 33 'WARNING' "Could not find the port binding in docker-compose.yaml"
            exit 1
        fi

        HEALTH_TEST_URL="http://0.0.0.0:$PORT/api/health"
        RESPONSE_CODE=$(wget --spider --server-response "$HEALTH_TEST_URL" 2>&1 | awk '/HTTP\/[0-9.]+ [0-9]+/ {print $2}' | head -n 1)

        if [ "$RESPONSE_CODE" -eq 200 ]; then
            message 42 'SUCCESS' "Health check passed. Endpoint $HEALTH_TEST_URL returned: $RESPONSE_CODE."
            touch "$HEALTH_CHECK_STATE_FILE"
            exit 0
        else
            message 31 'ERROR' "Health check failed. Endpoint $HEALTH_TEST_URL returned: $RESPONSE_CODE."
            exit 1
        fi
    ;;
    smoke)
        # 
    ;;
    unit)
        # 
    ;;
    e2e)
        message "Running E2E tests .."
        sh $0 service tester npx playwright test "$@"
    ;;
    all)
        message "Running test suite .."
        # sh $0 test smoke
        # sh $0 test unit
        sh $0 test e2e
    ;;
    *|help|--help|-h)
        message 33 "TEST" "Available test commands:"
        echo "  health          - Check service health endpoint"
        echo "  smoke           - Run smoke tests (placeholder)"
        echo "  unit            - Run unit tests (placeholder)"
        echo "  e2e             - Run end-to-end tests with Playwright"
        echo "  all             - Run all test suites"
        echo ""
        echo "Usage: cli test [health|smoke|unit|e2e|all]"
        exit 1
    ;;
esac