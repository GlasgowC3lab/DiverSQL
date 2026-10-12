WITH base AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        d.d_year,
        i.i_item_id,
        i.i_brand,
        r.r_reason_desc,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ws.web_name,
        wp.wp_url
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#45'
      AND cd.cd_gender = 'M'
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    d_date,
    i_item_id,
    r_reason_desc,
    cd_gender,
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    web_name,
    wp_url,
    return_amount,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY return_amount DESC) AS rn,
    RANK() OVER (ORDER BY total_return_amount DESC) AS customer_rank
FROM (
    SELECT
        c_customer_id,
        c_first_name,
        c_last_name,
        d_date,
        i_item_id,
        r_reason_desc,
        cd_gender,
        hd_buy_potential,
        ib_lower_bound,
        ib_upper_bound,
        web_name,
        wp_url,
        amt AS return_amount,
        SUM(amt) OVER (PARTITION BY c_customer_id) AS total_return_amount
    FROM base
    CROSS JOIN UNNEST(ARRAY[cr_return_amount, wr_return_amt]) AS t(amt)
) t
LIMIT 100
