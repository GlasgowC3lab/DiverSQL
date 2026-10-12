WITH
    /* Aggregate web sales per promotion, ship mode, year and income band */
    sales_agg AS (
        SELECT
            p.p_promo_id AS promo_id,
            sm.sm_code AS ship_mode,
            d.d_year AS sale_year,
            hd.hd_income_band_sk AS income_band_sk,
            SUM(ws.ws_ext_sales_price) AS total_sales,
            SUM(ws.ws_net_profit) AS total_profit,
            COUNT(*) AS order_cnt
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        WHERE d.d_year BETWEEN 2000 AND 2002                      -- filter 1
          AND sm.sm_code IN ('AIR', 'BIKE')                     -- filter 2
          AND p.p_discount_active = 'Y'                         -- filter 3
          AND cd.cd_gender = 'F'                                 -- filter 4
        GROUP BY
            p.p_promo_id,
            sm.sm_code,
            d.d_year,
            hd.hd_income_band_sk
    ),
    /* Aggregate store returns per promotion, year and income band */
    returns_agg AS (
        SELECT
            p.p_promo_id AS promo_id,
            CAST(NULL AS varchar) AS ship_mode,
            d.d_year AS sale_year,
            hd.hd_income_band_sk AS income_band_sk,
            SUM(sr.sr_return_amt) AS total_sales,
            SUM(sr.sr_net_loss) AS total_profit,
            COUNT(*) AS order_cnt
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        WHERE d.d_year BETWEEN 2000 AND 2002                      -- filter 5
          AND p.p_discount_active = 'Y'                         -- filter 6
          AND cd.cd_gender = 'F'                                 -- filter 7
        GROUP BY
            p.p_promo_id,
            d.d_year,
            hd.hd_income_band_sk
    ),
    /* Union the two aggregates (distinct) */
    union_raw AS (
        SELECT * FROM sales_agg
        UNION
        SELECT * FROM returns_agg
    ),
    /* Add a categorical column based on total_sales */
    union_cat AS (
        SELECT
            promo_id,
            ship_mode,
            sale_year,
            income_band_sk,
            total_sales,
            total_profit,
            order_cnt,
            CASE WHEN total_sales > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
        FROM union_raw
    ),
    /* Promotions that are not active – will be removed */
    promo_excluded AS (
        SELECT p.p_promo_id
        FROM promotion p
        WHERE p.p_discount_active = 'N'
    ),
    /* Remove rows that belong to excluded promotions using EXCEPT */
    union_minus_excluded AS (
        SELECT * FROM union_cat
        EXCEPT
        SELECT uc.*
        FROM union_cat uc
        JOIN promo_excluded pe ON uc.promo_id = pe.p_promo_id
    ),
    /* Full outer join with income_band to keep all income bands */
    full_join_income AS (
        SELECT
            ume.promo_id,
            ume.ship_mode,
            ume.sale_year,
            ume.income_band_sk,
            ume.total_sales,
            ume.total_profit,
            ume.order_cnt,
            ume.sales_category,
            ib.ib_income_band_sk
        FROM union_minus_excluded ume
        FULL OUTER JOIN income_band ib
            ON ume.income_band_sk = ib.ib_income_band_sk
        WHERE ib.ib_upper_bound IS NOT NULL                     -- filter 8
    ),
    /* Final aggregation with anti‑join and HAVING */
    final_agg AS (
        SELECT
            fji.sale_year,
            fji.sales_category,
            AVG(fji.total_sales) AS avg_total_sales,
            SUM(fji.total_profit) AS sum_total_profit
        FROM full_join_income fji
        WHERE NOT EXISTS (
            SELECT 1
            FROM store_returns sr2
            JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
            JOIN customer_demographics cd2 ON sr2.sr_cdemo_sk = cd2.cd_demo_sk
            WHERE cd2.cd_gender = 'M'
              AND d2.d_year = fji.sale_year
              AND sr2.sr_return_amt > 5000                     -- filter 9
        )
        GROUP BY fji.sale_year, fji.sales_category
        HAVING AVG(fji.total_sales) > 20000                     -- filter 10
    )
SELECT
    sale_year,
    sales_category,
    avg_total_sales,
    sum_total_profit
FROM final_agg
ORDER BY sale_year DESC, avg_total_sales DESC
LIMIT 100
