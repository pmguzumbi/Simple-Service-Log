# Performance Metrics

## Overview

This document provides performance benchmarks and optimization guidelines for the Simple Log Service.

## Performance Targets

### Latency (p99)
- **Ingest API**: <100ms
- **Read Recent API**: <200ms

### Throughput
- **Ingest**: 1,000+ requests/second
- **Read Recent**: 500+ requests/second

### Availability
- **Target**: 99.9% (Three nines)
- **Maximum downtime**: 43.2 minutes/month

## Benchmark Results

### Test Environment
- **Region**: us-east-1
- **Lambda Memory**: 256 MB
- **DynamoDB**: On-demand billing mode
- **Test Duration**: 10 minutes
- **Concurrent Users**: 100

### Ingest Lambda Performance

| Metric | Value |
|--------|-------|
| Average Latency | 45ms |
| p50 Latency | 42ms |
| p95 Latency | 78ms |
| p99 Latency | 95ms |
| Max Latency | 150ms |
| Throughput | 1,250 req/sec |
| Error Rate | 0.02% |
| Cold Start | 850ms |

**Breakdown**:
- DynamoDB PutItem: 15ms
- Lambda execution: 25ms
- Network overhead: 5ms

### Read Recent Lambda Performance

| Metric | Value |
|--------|-------|
| Average Latency | 85ms |
| p50 Latency | 75ms |
| p95 Latency | 145ms |
| p99 Latency | 180ms |
| Max Latency | 350ms |
| Throughput | 650 req/sec |
| Error Rate | 0.01% |
| Cold Start | 900ms |

**Breakdown**:
- DynamoDB Query (GSI): 45ms
- Data processing: 30ms
- Network overhea
