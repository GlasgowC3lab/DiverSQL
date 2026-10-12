select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 778 and 778+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'slate' or i_color = 'moccasin') and 
        (i_units = 'Gram' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'azure' or i_color = 'chocolate') and
        (i_units = 'Unknown' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'cornflower') and
        (i_units = 'Tsp' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'puff' or i_color = 'snow') and
        (i_units = 'Case' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'aquamarine' or i_color = 'tomato') and 
        (i_units = 'Each' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'lawn' or i_color = 'coral') and
        (i_units = 'Dram' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'beige' or i_color = 'lavender') and
        (i_units = 'Bunch' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'green') and
        (i_units = 'Pallet' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100
