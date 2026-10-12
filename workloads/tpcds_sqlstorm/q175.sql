SELECT
    d_year,
    s_state,
    i_category,
    i_class,
    i_brand,
    p_promo_name,
    hd_buy_potential,
    total_quantity,
    total_net_paid,
    total_net_profit,
    sales_count,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        d.d_year,
        s.s_state,
        i.i_category,
        i.i_class,
        i.i_brand,
        p.p_promo_name,
        hd.hd_buy_potential,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2000
      AND i.i_category = 'Sports'
      AND p.p_discount_active = 'Y'
      AND cd.cd_gender = 'M'
      AND s.s_state = 'TX'
    GROUP BY
        d.d_year,
        s.s_state,
        i.i_category,
        i.i_class,
        i.i_brand,
        p.p_promo_name,
        hd.hd_buy_potential
) t
ORDER BY profit_rank
LIMIT 100
