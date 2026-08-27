function enableTelemetry() {
  const connectionString = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;

  if (!connectionString) {
    return false;
  }

  const { useAzureMonitor } = require("@azure/monitor-opentelemetry");

  useAzureMonitor({
    azureMonitorExporterOptions: {
      connectionString
    },
    instrumentationOptions: {
      console: {
        enabled: false
      }
    }
  });

  return true;
}

module.exports = {
  enableTelemetry
};
