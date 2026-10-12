WITH sr_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk
),
promo_web AS (
    SELECT
        p.p_promo_id,
        p.p_start_date_sk,
        p.p_discount_active,
        w.wp_web_page_id,
        w.wp_creation_date_sk,
        w.wp_type,
        w.wp_autogen_flag
    FROM promotion p
    FULL OUTER JOIN web_page w
        ON p.p_start_date_sk = w.wp_creation_date_sk
    WHERE p.p_discount_active = 'Y' OR w.wp_autogen_flag = 'Y'
),
aggregated AS (
    SELECT
        d.d_year,
        s.s_store_name,
        COALESCE(pw.p_promo_id, 'NO_PROMO') AS promo_id,
        SUM(a.total_net_loss) AS sum_net_loss,
        SUM(a.return_cnt) AS total_returns
    FROM sr_agg a
    JOIN store s
        ON a.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON a.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promo_web pw
        ON COALESCE(pw.p_start_date_sk, pw.wp_creation_date_sk) = d.d_date_sk
    WHERE
        s.s_state = 'CA'
        AND d.d_year BETWEEN 2000 AND 2002
        AND cc.cc_employees > 150
        AND cd.cd_gender = 'F'
        AND r.r_reason_desc <> 'Other'
        AND (pw.wp_type = 'Content' OR pw.wp_type IS NULL)
    GROUP BY ROLLUP (d.d_year, s.s_store_name, pw.p_promo_id)
)
SELECT
    agg.d_year,
    agg.s_store_name,
    agg.promo_id,
    agg.sum_net_loss,
    agg.total_returns,
    RANK() OVER (PARTITION BY agg.d_year ORDER BY agg.sum_net_loss DESC) AS loss_rank
FROM aggregated agg
ORDER BY agg.d_year ASC, loss_rank ASC, agg.sum_net_loss DESC
