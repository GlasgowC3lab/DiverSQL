WITH
    store_sales_agg AS (
        SELECT s.s_store_sk AS key_id,
               d.d_year,
               SUM(ss.ss_ext_sales_price) AS total_sales
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY s.s_store_sk, d.d_year
    ),
    web_sales_agg AS (
        SELECT w.w_warehouse_sk AS key_id,
               d.d_year,
               SUM(ws.ws_ext_sales_price) AS total_sales
        FROM web_sales ws
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY w.w_warehouse_sk, d.d_year
    ),
    combined_sales AS (
        SELECT key_id, d_year, total_sales FROM store_sales_agg
        UNION ALL
        SELECT key_id, d_year, total_sales FROM web_sales_agg
    ),
    filtered_sales AS (
        SELECT *
        FROM combined_sales cs
        WHERE cs.key_id NOT IN (
            SELECT DISTINCT sr.sr_store_sk
            FROM store_returns sr
            JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
            WHERE dr.d_year = 2001
        )
    ),
    small_years AS (
        SELECT DISTINCT d_year
        FROM date_dim
        WHERE d_year = 2001
    )
SELECT DISTINCT fy.d_year,
       fs.key_id,
       fs.total_sales
FROM small_years fy
CROSS JOIN filtered_sales fs
WHERE fs.d_year = fy.d_year
ORDER BY fs.total_sales DESC
LIMIT 100
