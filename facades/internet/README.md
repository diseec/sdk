# Internet Connectivity Checker (Optimized)

This is an optimized version of the internet connectivity checker, designed specifically for Alpine Linux containers. It provides fast and reliable diagnosis of internet connectivity issues, with special handling for VPN environments and Iranian internet censorship.

## Features

- **Alpine-optimized**: Designed to work efficiently in Alpine Docker containers
- **Lightweight**: Uses minimal dependencies available in the base Docker image
- **VPN-aware**: Special handling for container environments with VPN on host
- **Censorship detection**: Identifies filtering patterns common in Iranian internet
- **Multi-layer testing**: Tests gateway, DNS, HTTP(S), and CDN access
- **Detailed diagnostics**: Provides specific recommendations based on failure patterns
- **Configurable**: All parameters easily customizable through the config.sh file

## Usage

```bash
# Quick silent check (returns 0 if online, 1 if offline)
D int_optimized iso

# Basic connectivity test with output (fast, ~2 seconds)
D int_optimized test

# Full diagnostic with all tests (~30 seconds)
D int_optimized diagnose

# Silent mode
D int_optimized test --silent
```

## Configuration

All configuration options are centralized in the `config.sh` file. You can customize the following settings:

### Timeouts

- `QUICK_TIMEOUT`: Timeout for basic connectivity tests (default: 1s)
- `CONNECT_TIMEOUT`: Connection timeout for HTTP requests (default: 2s)
- `DNS_RESOLUTION_TIMEOUT`: Timeout for DNS resolution tests (default: 2s)
- `TRACEROUTE_TIMEOUT`: Timeout for traceroute commands (default: 10s)

### Test Targets

- `QUICK_SITE`: Main site for quick connectivity tests (default: diseec.com)
- `PRIMARY_DNS_SERVER`: Primary DNS server to test (default: 8.8.8.8)
- `SECONDARY_DNS_SERVER`: Secondary DNS server to test (default: 1.1.1.1)
- `INTERNATIONAL_SITES`: Array of international sites to test
- `REGIONAL_SITES`: Array of regional (Iranian) sites to test
- `CDN_SITES`: Array of CDN sites to test

### Performance Thresholds

- `GOOD_LATENCY_THRESHOLD`: Threshold for good latency in ms (default: 100ms)
- `ACCEPTABLE_PACKET_LOSS`: Acceptable packet loss percentage (default: 5%)
- `GOOD_SPEED_THRESHOLD`: Threshold for good download speed (default: 10 Mbps)

### Censorship Detection

- `CENSORSHIP_TEST_SITE1`, `CENSORSHIP_TEST_SITE2`, `CENSORSHIP_TEST_SITE3`: Sites used to detect censorship
- `LOCAL_TEST_SITE`, `LOCAL_TEST_SITE2`: Local sites used to verify regional access

## Comparison with Original Version

The optimized version differs from the original in several ways:

1. **BusyBox compatibility**: Avoids using incompatible grep patterns and commands
2. **VPN awareness**: Better handling of DNS failures when internet still works
3. **Faster execution**: Optimized tests that complete more quickly
4. **Improved error handling**: More robust error detection and graceful fallbacks
5. **Better feedback**: More specific and actionable diagnostic messages
6. **Centralized configuration**: All parameters easily customizable in config.sh

## Requirements

All required tools are included in the Dockerfile:

- wget, iputils, bind-tools, traceroute, bc

## Troubleshooting

If you encounter issues:

1. Check if all required packages are installed in the container
2. Verify network configuration in Docker
3. For VPN environments, expect DNS server ping failures even when internet works
4. Try adjusting the timeout settings in config.sh for slower connections

## Customization

To adapt for different environments:

1. Edit the config.sh file to change timeouts, test targets, or thresholds
2. Add or remove test sites from the respective arrays
3. Adjust performance thresholds based on your network expectations
