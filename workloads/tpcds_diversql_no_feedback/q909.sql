WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        d.d_year,
        c.c_customer_id,
        cd.cd_gender,
        ca.ca_state,
        s.s_store_name,
        r.r_reason_desc,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        inv.inv_quantity_on_hand,
        w.w_warehouse_name,
        p.p_promo_name,
        cp.cp_type,
        ws.web_name
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    FULL OUTER JOIN inventory inv ON d.d_date_sk = inv.inv_date_sk
    FULL OUTER JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ca.ca_country = 'United States'
      AND s.s_state = 'CA'
      AND r.r_reason_desc LIKE '%size%'
      AND p.p_channel_press = 'N'
      AND cp.cp_type = 'A'
      AND ws.web_name = 'www.example.com'
      AND inv.inv_item_sk IN (SELECT p_item_sk FROM promotion WHERE p_discount_active = 'Y')
),
per_store AS (
    SELECT
        d_year,
        s_store_name,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        SUM(inv_quantity_on_hand) AS total_quantity,
        AVG(inv_quantity_on_hand) AS avg_quantity
    FROM base
    GROUP BY d_year, s_store_name
)
SELECT
    d_year,
    SUM(total_quantity) AS year_total_quantity,
    AVG(avg_quantity) AS year_avg_quantity_per_store,
    SUM(unique_customers) AS year_total_customers
FROM per_store
GROUP BY d_year
ORDER BY d_year DESC
LIMIT 100
