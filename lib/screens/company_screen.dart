import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../core/external_links.dart';
import '../data/santigrill_catalog.dart';
import '../widgets/shared.dart';

/// Contato e informações institucionais da SantiGrill, com dados oficiais
/// de assets/data/santigrill.json.
class CompanyScreen extends StatelessWidget {
  const CompanyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final company = state.company;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fale com a SantiGrill',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const Center(child: BrandLogo()),
          if (company.highlights.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in company.highlights)
                  StatusPill(
                    label: item.split(' - ').first,
                    color: AppColors.red,
                    background: AppColors.redSoft,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          ContactActions(company: company),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                if (company.businessHours != null)
                  _InfoTile(
                    icon: Icons.schedule,
                    title: 'Horário de atendimento',
                    value: company.businessHours!,
                  ),
                if (company.address.isNotEmpty)
                  _InfoTile(
                    icon: Icons.location_on_outlined,
                    title: 'Endereço',
                    value: company.address,
                    actionLabel: 'Abrir no mapa',
                    onTap: () => ExternalLinks.map(
                      context,
                      '${company.legalName ?? company.name}, ${company.address}',
                    ),
                  ),
                for (final phone in company.phones)
                  _InfoTile(
                    icon: Icons.call_outlined,
                    title: phone == company.whatsapp
                        ? 'Telefone / WhatsApp'
                        : 'Telefone',
                    value: phone,
                    actionLabel: 'Ligar',
                    onTap: () => ExternalLinks.phone(context, phone),
                  ),
                for (final email in company.emails)
                  _InfoTile(
                    icon: Icons.mail_outline,
                    title: email.startsWith('vendas')
                        ? 'E-mail de vendas'
                        : 'E-mail de assistência',
                    value: email,
                    actionLabel: 'Enviar e-mail',
                    onTap: () => ExternalLinks.email(
                      context,
                      email,
                      subject: 'Contato pelo app SantiGrill',
                    ),
                  ),
                if (company.facebook != null)
                  _InfoTile(
                    icon: Icons.thumb_up_alt_outlined,
                    title: 'Facebook',
                    value: 'churrasqueirassantigrill',
                    actionLabel: 'Abrir',
                    onTap: () => ExternalLinks.url(context, company.facebook!),
                  ),
                if (company.website != null)
                  _InfoTile(
                    icon: Icons.language,
                    title: 'Loja on-line',
                    value: company.website!.replaceFirst('https://', ''),
                    actionLabel: 'Abrir',
                    onTap: () => ExternalLinks.url(context, company.website!),
                  ),
              ],
            ),
          ),
          if (state.catalog.info.isNotEmpty) ...[
            const SizedBox(height: 24),
            const SectionHeading(title: 'Políticas da loja'),
            const SizedBox(height: 8),
            for (final section in state.catalog.info)
              InfoSectionTile(section: section),
          ],
          const SizedBox(height: 20),
          if (company.legalName != null || company.cnpj != null)
            Text(
              [
                company.legalName,
                if (company.cnpj != null) 'CNPJ ${company.cnpj}',
              ].whereType<String>().join(' · '),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

/// Botões rápidos de WhatsApp, ligação e e-mail.
class ContactActions extends StatelessWidget {
  const ContactActions({super.key, required this.company});

  final CompanyInfo company;

  @override
  Widget build(BuildContext context) {
    final phone = company.phones.isEmpty ? null : company.phones.first;
    final email = company.emails.isEmpty
        ? null
        : company.emails.firstWhere(
            (item) => item.startsWith('vendas'),
            orElse: () => company.emails.first,
          );
    return Row(
      children: [
        if (company.whatsapp != null)
          Expanded(
            child: _ContactButton(
              icon: Icons.chat_outlined,
              label: 'WhatsApp',
              color: AppColors.success,
              onTap: () => ExternalLinks.whatsapp(
                context,
                company,
                message: 'Olá! Vim pelo aplicativo da SantiGrill.',
              ),
            ),
          ),
        if (phone != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _ContactButton(
              icon: Icons.call_outlined,
              label: 'Ligar',
              color: AppColors.red,
              onTap: () => ExternalLinks.phone(context, phone),
            ),
          ),
        ],
        if (email != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _ContactButton(
              icon: Icons.mail_outline,
              label: 'E-mail',
              color: AppColors.ink,
              onTap: () => ExternalLinks.email(
                context,
                email,
                subject: 'Contato pelo app SantiGrill',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.red),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Tooltip(
                message: actionLabel ?? 'Abrir',
                child: const Icon(Icons.chevron_right, color: AppColors.muted),
              ),
          ],
        ),
      ),
    );
  }
}

/// Seção de política (pagamento, entrega, garantia, trocas) expansível.
class InfoSectionTile extends StatelessWidget {
  const InfoSectionTile({super.key, required this.section});

  final InfoSection section;

  static const _icons = {
    'pagamento': Icons.payments_outlined,
    'entrega': Icons.local_shipping_outlined,
    'garantia': Icons.verified_outlined,
    'trocas': Icons.swap_horiz,
    'seguranca': Icons.lock_outline,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        leading: Icon(
          _icons[section.id] ?? Icons.info_outline,
          color: AppColors.red,
        ),
        title: Text(
          section.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.body,
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
          if (section.url != null)
            TextButton.icon(
              onPressed: () => ExternalLinks.url(context, section.url!),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Ver no site'),
            ),
        ],
      ),
    );
  }
}
