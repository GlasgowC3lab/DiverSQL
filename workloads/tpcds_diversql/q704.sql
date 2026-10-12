WITH
    sampled_sales AS (
        SELECT *
        FROM store_sales TABLESAMPLE BERNOULLI (10)
    ),
    except_pages AS (
        SELECT cp.cp_catalog_page_sk
        FROM catalog_page cp
        EXCEPT
        SELECT cr.cr_catalog_page_sk
        FROM catalog_returns cr
    ),
    joined_all AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            ss.ss_sold_date_sk,
            ss.ss_net_paid,
            ss.ss_net_profit,
            s.s_state,
            ca.ca_country,
            p.p_discount_active,
            cd.cd_gender,
            hd.hd_buy_potential,
            ib.ib_income_band_sk,
            r.r_reason_desc,
            ws.web_state,
            cp.cp_catalog_page_sk,
            cr.cr_return_amount,
            wr.wr_return_amt
        FROM date_dim d
        JOIN sampled_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
        JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
        LEFT JOIN except_pages ep ON cp.cp_catalog_page_sk = ep.cp_catalog_page_sk
        JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        FULL OUTER JOIN web_returns wr ON cr.cr_returned_date_sk = wr.wr_returned_date_sk
        LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
        WHERE d.d_year BETWEEN 1999 AND 2001
          AND s.s_state IN ('CA', 'NY')
          AND ca.ca_country = 'United States'
          AND p.p_discount_active = 'Y'
          AND ss.ss_net_paid > 0
          AND ss.ss_store_sk IN (SELECT s_store_sk FROM store WHERE s_state = 'TX')
    )
SELECT
    d_year,
    s_state,
    COUNT(DISTINCT ss_sold_date_sk) AS days_sold,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_net_profit) AS avg_net_profit,
    COUNT(DISTINCT cp_catalog_page_sk) AS catalog_page_count,
    SUM(cr_return_amount) AS total_catalog_return,
    SUM(wr_return_amt) AS total_web_return,
    COUNT(DISTINCT ib_income_band_sk) AS income_band_used
FROM joined_all
GROUP BY d_year, s_state
ORDER BY total_net_paid DESC
LIMIT 100
