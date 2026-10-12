WITH base AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        cc.cc_division_name,
        d.d_year,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ss.ss_net_profit) AS store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND cc.cc_division_name = 'cally'
      AND s.s_state = 'CA'
      AND s.s_number_employees > 200
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk BETWEEN 1 AND 5
    GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name, s.s_state,
             cc.cc_division_name, d.d_year, cd.cd_gender, hd.hd_income_band_sk
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        d.d_year,
        SUM(sr.sr_return_amt) AS total_returns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY sr.sr_store_sk, d.d_year
),
excluded_stores AS (
    SELECT s_store_id FROM store WHERE s_state = 'TX'
    EXCEPT
    SELECT s_store_id FROM store WHERE s_number_employees < 300
)
SELECT
    ROW_NUMBER() OVER (ORDER BY b.store_sales DESC) AS row_num,
    b.s_store_id,
    b.s_store_name,
    b.s_state,
    b.cc_division_name,
    b.d_year,
    b.store_sales,
    b.store_profit,
    b.sales_transactions,
    b.total_inventory,
    (
        SELECT ra.total_returns
        FROM returns_agg ra
        WHERE ra.sr_store_sk = b.s_store_sk
          AND ra.d_year = b.d_year
    ) AS total_returns,
    CASE WHEN b.s_store_id IN (SELECT s_store_id FROM excluded_stores) THEN 'EXCLUDED' ELSE 'INCLUDED' END AS inclusion_flag
FROM base b
WHERE b.store_sales > 10000
ORDER BY b.store_sales DESC
OFFSET 0 FETCH FIRST 100 ROWS ONLY
