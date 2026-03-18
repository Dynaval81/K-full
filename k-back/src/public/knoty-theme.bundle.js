// Knoty Admin — HAI3 Airy Style Theme Bundle
// Sets window.THEME before AdminJS.Application renders.
// Executed after design-system.bundle.js (AdminJSDesignSystem global is available).
(function () {
  'use strict';

  var ds = window.AdminJSDesignSystem;
  if (!ds || !ds.theme) return;

  var base = ds.theme;

  window.THEME = Object.assign({}, base, {
    colors: Object.assign({}, base.colors || {}, {
      // Gold primary — replaces the default blue
      primary100: '#E6B800',
      primary80:  '#C9A200',
      primary60:  '#DAAE00',
      primary40:  '#EDD860',
      primary20:  '#FFF8CC',
      accent:     '#E6B800',
      love:       '#E6B800',
      info:       '#5B8DEF',
      success:    '#2E7D32',
      error:      '#CC0000',
      // Backgrounds — clean white/grey
      bg:         '#F5F5F5',
      sidebar:    '#FFFFFF',
      container:  '#FFFFFF',
      filterBg:   '#FFFFFF',
      // Text
      text:       '#1A1A1A',
      grey100:    '#1A1A1A',
      grey80:     '#3D3D3D',
      grey60:     '#6B6B6B',
      grey40:     '#AAAAAA',
      grey20:     '#F0F0F0',
      // Borders
      border:     '#E0E0E0',
      inputBorder:'#E0E0E0',
    }),
    borders: Object.assign({}, base.borders || {}, {
      default: '1px solid #E0E0E0',
      input:   '1px solid #E0E0E0',
    }),
    shadows: Object.assign({}, base.shadows || {}, {
      login:     '0 8px 32px rgba(0,0,0,0.08)',
      cardHover: '0 4px 12px rgba(0,0,0,0.08)',
      drawer:    '-2px 0 8px rgba(0,0,0,0.06)',
      card:      '0 1px 6px rgba(0,0,0,0.05)',
    }),
  });
}());
