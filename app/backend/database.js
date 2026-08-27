const sql = require("mssql");

const server = process.env.AZURE_SQL_SERVER;
const database = process.env.AZURE_SQL_DATABASE;
const port = Number(process.env.AZURE_SQL_PORT || 1433);
let poolPromise;

function isDatabaseConfigured() {
  return Boolean(server && database);
}

async function getPool() {
  if (!isDatabaseConfigured()) {
    return null;
  }

  if (!poolPromise) {
    poolPromise = sql.connect({
      server,
      port,
      database,
      authentication: {
        type: "azure-active-directory-default"
      },
      options: {
        encrypt: true,
        trustServerCertificate: false
      }
    }).catch((error) => {
      poolPromise = null;
      throw error;
    });
  }

  return poolPromise;
}

async function getSecurityControls() {
  const pool = await getPool();
  const result = await pool.request().query(`
    SELECT Id AS id, Name AS name
    FROM dbo.SecurityControl
    ORDER BY Id;
  `);

  return result.recordset;
}

module.exports = {
  getSecurityControls,
  isDatabaseConfigured
};
