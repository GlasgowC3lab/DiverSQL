WITH ss_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        cd.cd_dep_count
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND ss.ss_ext_sales_price > 100
      AND cd.cd_dep_count >= 1
      AND ss.ss_quantity >= 1
),
cr_base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        d.d_year AS ret_year,
        d.d_month_seq AS ret_month_seq,
        sm.sm_code,
        sm.sm_contract,
        ws.web_name,
        cd_ret.cd_dep_employed_count
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd_ret
        ON cr.cr_refunded_cdemo_sk = cd_ret.cd_demo_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cr.cr_return_amount > 0
      AND sm.sm_code = 'AIR'
      AND cd_ret.cd_dep_employed_count > 1
      AND ws.web_name LIKE '%Online%'
)
SELECT
    COALESCE(ss.d_year, cr.ret_year) AS year,
    COALESCE(ss.d_month_seq, cr.ret_month_seq) AS month_seq,
    ss.ss_item_sk,
    cr.cr_item_sk AS return_item_sk,
    ss.ss_ext_sales_price,
    cr.cr_return_amount,
    ss.ss_ext_sales_price - COALESCE(cr.cr_return_amount, 0) AS net_sales_minus_return,
    ss.cd_gender,
    sm.sm_code,
    ws.web_name,
    CASE WHEN cr.cr_return_amount IS NULL THEN 'SALE' ELSE 'RETURN' END AS transaction_type,
    ROW_NUMBER() OVER (
        PARTITION BY ss.ss_store_sk
        ORDER BY ss.ss_ext_sales_price DESC
    ) AS sales_rank,
    RANK() OVER (
        PARTITION BY COALESCE(ss.d_year, cr.ret_year)
        ORDER BY (ss.ss_ext_sales_price - COALESCE(cr.cr_return_amount, 0)) DESC
    ) AS profit_rank
FROM ss_base ss
FULL OUTER JOIN cr_base cr
    ON ss.ss_sold_date_sk = cr.cr_returned_date_sk
LEFT JOIN ship_mode sm
    ON cr.sm_code = sm.sm_code
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = ss.ss_sold_date_sk
WHERE (ss.ss_ext_sales_price - COALESCE(cr.cr_return_amount, 0)) > 0
  AND (ss.cd_gender = 'M' OR ss.cd_gender = 'F')
  AND (sm.sm_contract IS NOT NULL)
  AND (ws.web_country = 'United States')
ORDER BY year DESC, month_seq DESC, profit_rank ASC
LIMIT 100
