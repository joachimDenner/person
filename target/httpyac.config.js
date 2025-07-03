
const fs = require('fs');
const path = require('path');

// Define the log file path relative to the config file location
const LOG_FILE_PATH = path.join(__dirname, 'httpyac_errors.log');

// Helper function to format error groups
const formatErrorGroup = (title, params) => {
  if (params.length === 0) return '';
  return `${title}:\n${params.map(p => `  - ${p}`).join('\n')}\n`;
};

module.exports = {
  configureHooks: function (api) {
    api.hooks.onRequest.addHook('validatePlaceholders', function (request) {
      const missingParams = {
        path: [],
        query: [],
        header: []
      };

      // Check URL path parameters
      const url = new URL(request.url);
      const decodedPath = decodeURIComponent(url.pathname);
      const pathParamRegex = /[{]([^{}]+)[}]/g;
      const pathMatches = [...decodedPath.matchAll(pathParamRegex)];
      
      pathMatches.forEach(match => {
        missingParams.path.push(match[1]);
      });

      // Check query parameters
      for (const [key, value] of url.searchParams.entries()) {
        if (value === '{?}') {
          missingParams.query.push(key);
        }
      }

      // Check headers
      for (const [key, value] of Object.entries(request.headers || {})) {
        if (value === '{?}') {
          missingParams.header.push(key);
        }
      }

      // Check if any parameters are missing
      const hasMissingParams = Object.values(missingParams)
        .some(group => group.length > 0);

      if (hasMissingParams) {
        const errorMessage = [
          `Request to "${request.url}" has missing required parameters:\n`,
          formatErrorGroup('Path Parameters', missingParams.path),
          formatErrorGroup('Query Parameters', missingParams.query),
          formatErrorGroup('Header Parameters', missingParams.header),
          '\nPlease provide values for these parameters before sending the request.'
        ].filter(Boolean).join('\n');

        // Write to log file
        fs.writeFileSync(LOG_FILE_PATH, errorMessage, 'utf8');
      }
    });
  }
};