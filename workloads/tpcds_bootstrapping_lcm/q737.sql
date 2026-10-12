WITH base AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_quarter_name,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_tax_percentage,
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss AS cr_net_loss,
        cd_ref.cd_gender AS cr_refunded_gender,
        cd_ret.cd_gender AS cr_returning_gender,
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_net_loss AS wr_net_loss,
        cd_wr_ref.cd_gender AS wr_refunded_gender,
        cd_wr_ret.cd_gender AS wr_returning_gender
    FROM date_dim d
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    LEFT JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN customer_demographics cd_wr_ref
        ON wr.wr_refunded_cdemo_sk = cd_wr_ref.cd_demo_sk
    LEFT JOIN customer_demographics cd_wr_ret
        ON wr.wr_returning_cdemo_sk = cd_wr_ret.cd_demo_sk
    WHERE d.d_year = 2000
),
aggregated AS (
    SELECT
        d_date_sk,
        d_year,
        d_quarter_name,
        s_store_id,
        s_store_name,
        s_state,
        s_tax_percentage,
        COUNT(DISTINCT cr_order_number)                                    AS catalog_return_txns,
        COUNT(DISTINCT wr_order_number)                                    AS web_return_txns,
        COALESCE(SUM(cr_return_amount), 0)                                 AS catalog_return_total,
        COALESCE(SUM(wr_return_amt), 0)                                    AS web_return_total,
        COALESCE(SUM(cr_return_amount), 0) + COALESCE(SUM(wr_return_amt), 0) AS total_return_amount,
        COALESCE(SUM(cr_net_loss), 0)                                      AS catalog_net_loss_total,
        COALESCE(SUM(wr_net_loss), 0)                                      AS web_net_loss_total,
        CASE
            WHEN (COALESCE(SUM(cr_return_amount), 0) + COALESCE(SUM(wr_return_amt), 0)) = 0
                THEN 0.0
            ELSE (COALESCE(SUM(cr_net_loss), 0) + COALESCE(SUM(wr_net_loss), 0)) /
                 (COALESCE(SUM(cr_return_amount), 0) + COALESCE(SUM(wr_return_amt), 0))
        END                                                               AS net_loss_per_dollar_returned,
        AVG(cr_return_quantity)                                            AS avg_catalog_return_quantity,
        AVG(wr_return_quantity)                                            AS avg_web_return_quantity,
        SUM(CASE WHEN cr_refunded_gender = 'M' THEN 1 ELSE 0 END)          AS catalog_refunded_male_cnt,
        SUM(CASE WHEN cr_refunded_gender = 'F' THEN 1 ELSE 0 END)          AS catalog_refunded_female_cnt,
        SUM(CASE WHEN cr_returning_gender = 'M' THEN 1 ELSE 0 END)         AS catalog_returning_male_cnt,
        SUM(CASE WHEN cr_returning_gender = 'F' THEN 1 ELSE 0 END)         AS catalog_returning_female_cnt,
        SUM(CASE WHEN wr_refunded_gender = 'M' THEN 1 ELSE 0 END)          AS web_refunded_male_cnt,
        SUM(CASE WHEN wr_refunded_gender = 'F' THEN 1 ELSE 0 END)          AS web_refunded_female_cnt,
        SUM(CASE WHEN wr_returning_gender = 'M' THEN 1 ELSE 0 END)         AS web_returning_male_cnt,
        SUM(CASE WHEN wr_returning_gender = 'F' THEN 1 ELSE 0 END)         AS web_returning_female_cnt
    FROM base
    GROUP BY
        d_date_sk,
        d_year,
        d_quarter_name,
        s_store_id,
        s_store_name,
        s_state,
        s_tax_percentage
    HAVING COALESCE(SUM(cr_return_amount), 0) + COALESCE(SUM(wr_return_amt), 0) > 0
)
SELECT
    d_date_sk,
    d_year,
    d_quarter_name,
    s_store_id,
    s_store_name,
    s_state,
    s_tax_percentage,
    catalog_return_txns,
    web_return_txns,
    catalog_return_total,
    web_return_total,
    total_return_amount,
    catalog_net_loss_total,
    web_net_loss_total,
    net_loss_per_dollar_returned,
    avg_catalog_return_quantity,
    avg_web_return_quantity,
    catalog_refunded_male_cnt,
    catalog_refunded_female_cnt,
    catalog_returning_male_cnt,
    catalog_returning_female_cnt,
    web_refunded_male_cnt,
    web_refunded_female_cnt,
    web_returning_male_cnt,
    web_returning_female_cnt,
    ROW_NUMBER() OVER (PARTITION BY d_quarter_name ORDER BY total_return_amount DESC) AS store_quarter_rank
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
