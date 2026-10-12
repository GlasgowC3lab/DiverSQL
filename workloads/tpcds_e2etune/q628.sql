WITH sales_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        p.p_channel_email,
        p.p_channel_tv,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    INNER JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
      AND p.p_discount_active = 'Y'
      AND (p.p_channel_email = 'Y' OR p.p_channel_tv = 'Y')
    GROUP BY cd.cd_gender, cd.cd_marital_status, p.p_channel_email, p.p_channel_tv
),
returns_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cc.cc_class,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    INNER JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    INNER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
      AND cc.cc_class = 'large'
    GROUP BY cd.cd_gender, cd.cd_marital_status, cc.cc_class
)
SELECT
    s.cd_gender,
    s.cd_marital_status,
    s.p_channel_email,
    s.p_channel_tv,
    s.total_net_paid,
    s.total_net_profit,
    s.avg_discount_amt,
    s.sales_cnt,
    r.total_return_amount,
    r.total_net_loss,
    r.avg_return_tax,
    r.returns_cnt,
    (r.total_return_amount / NULLIF(s.total_net_paid, 0)) * 100 AS return_rate_pct,
    RANK() OVER (ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cd_gender = r.cd_gender
   AND s.cd_marital_status = r.cd_marital_status
ORDER BY s.total_net_profit DESC
LIMIT 100
