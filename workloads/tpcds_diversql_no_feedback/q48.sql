WITH first_part AS (
    SELECT
        sm.sm_code || '_' || sm.sm_carrier AS mode_desc,
        regexp_extract(sm.sm_contract, '([A-Z]{2})', 1) AS contract_part,
        sum(ws.ws_ext_sales_price) AS total_sales,
        count(DISTINCT ws.ws_order_number) AS orders_cnt
    FROM tpcds.web_sales ws
    JOIN tpcds.ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(sm.sm_contract, '^P[0-9]')
      AND sm.sm_code LIKE 'A%'
      AND NOT EXISTS (
          SELECT 1
          FROM tpcds.web_sales ws2
          WHERE ws2.ws_order_number = ws.ws_order_number
            AND ws2.ws_ship_mode_sk <> ws.ws_ship_mode_sk
      )
    GROUP BY sm.sm_code, sm.sm_carrier, sm.sm_contract
),
second_part AS (
    SELECT
        sm.sm_code || '_' || sm.sm_carrier AS mode_desc,
        regexp_extract(sm.sm_contract, '([a-z]+)$', 1) AS contract_part,
        sum(ws.ws_ext_sales_price) AS total_sales,
        count(DISTINCT ws.ws_order_number) AS orders_cnt
    FROM tpcds.web_sales ws
    JOIN tpcds.ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code = 'AIR'
      AND sm.sm_contract LIKE '%Z3'
      AND NOT EXISTS (
          SELECT 1
          FROM tpcds.web_sales ws2
          WHERE ws2.ws_order_number = ws.ws_order_number
            AND ws2.ws_ship_mode_sk <> ws.ws_ship_mode_sk
      )
    GROUP BY sm.sm_code, sm.sm_carrier, sm.sm_contract
)
SELECT mode_desc, contract_part, total_sales, orders_cnt
FROM (
    SELECT mode_desc, contract_part, total_sales, orders_cnt FROM first_part
    UNION
    SELECT mode_desc, contract_part, total_sales, orders_cnt FROM second_part
) u
ORDER BY total_sales DESC, mode_desc ASC
LIMIT 100
