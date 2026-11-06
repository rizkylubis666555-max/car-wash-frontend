import 'package:flutter/material.dart';

import 'owner_brand_tab.dart';
import 'owner_layanan_tab.dart';
import 'owner_member_tab.dart';
import 'owner_promo_tab.dart';
import 'owner_user_tab.dart';

class OwnerConfigurationTab extends StatelessWidget {
  const OwnerConfigurationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: Column(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    Tab(text: 'Kelola Akun'),
                    Tab(text: 'Kelola Member'),
                    Tab(text: 'Kelola Layanan'),
                    Tab(text: 'Kelola Merek'),
                    Tab(text: 'Kelola Promo'),
                  ],
                ),
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  OwnerUserTab(),
                  OwnerMemberTab(),
                  OwnerLayananTab(),
                  OwnerBrandTab(),
                  OwnerPromoTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
