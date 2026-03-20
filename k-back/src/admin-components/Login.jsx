import React, { useMemo } from 'react';
import { Box, Button, DropDown, DropDownItem, DropDownMenu, DropDownTrigger,
         FormGroup, H2, H5, Icon, Input, Label, MessageBox, Text } from '@adminjs/design-system';
import { useSelector } from 'react-redux';
import { useTranslation } from 'adminjs';

const Login = () => {
  const props = window.__APP_STATE__;
  const { action, errorMessage: message } = props;

  const { translateComponent, translateMessage, i18n } = useTranslation();
  const branding = useSelector(state => state.branding);

  const supportedLngs = i18n?.options?.supportedLngs ?? [];
  const availableLanguages = useMemo(
    () => supportedLngs.filter(l => l !== 'cimode'),
    [supportedLngs],
  );
  const currentLang = i18n?.language ?? 'de';

  return (
    <Box
      flex
      variant="grey"
      style={{
        alignItems: 'center',
        justifyContent: 'center',
        flexDirection: 'column',
        minHeight: '100vh',
        background: '#F5F5F5',
      }}
    >
      {/* Language selector — top right */}
      {availableLanguages.length > 1 && (
        <Box style={{ position: 'fixed', top: 16, right: 24, zIndex: 100 }}>
          <DropDown>
            <DropDownTrigger>
              <Button variant="text" style={{ color: '#6B6B6B', fontSize: 13, fontWeight: 600 }}>
                <Icon icon="Globe" />
                {translateComponent(`LanguageSelector.availableLanguages.${currentLang}`, { defaultValue: currentLang.toUpperCase() })}
              </Button>
            </DropDownTrigger>
            <DropDownMenu>
              {availableLanguages.map(lang => (
                <DropDownItem key={lang} onClick={() => i18n.changeLanguage(lang)}>
                  {translateComponent(`LanguageSelector.availableLanguages.${lang}`, { defaultValue: lang.toUpperCase() })}
                </DropDownItem>
              ))}
            </DropDownMenu>
          </DropDown>
        </Box>
      )}

      {/* Login card */}
      <Box
        bg="white"
        flex
        boxShadow="login"
        style={{
          borderRadius: 20,
          overflow: 'hidden',
          width: '100%',
          maxWidth: 820,
          minHeight: 420,
        }}
      >
        {/* Left panel — branding */}
        <Box
          bg="primary100"
          style={{
            width: 360,
            flexShrink: 0,
            padding: '48px 40px',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'center',
          }}
          className="login__left-panel"
        >
          {branding.logo && (
            <img
              src={branding.logo}
              alt={branding.companyName}
              style={{ height: 80, width: 'auto', objectFit: 'contain', marginBottom: 32 }}
            />
          )}
          <H2 style={{ color: '#fff', fontWeight: 700, marginBottom: 12, fontSize: 28 }}>
            {translateComponent('Login.welcomeHeader')}
          </H2>
          <Text style={{ color: 'rgba(255,255,255,0.85)', fontSize: 15, lineHeight: 1.6 }}>
            {translateComponent('Login.welcomeMessage')}
          </Text>
        </Box>

        {/* Right panel — form */}
        <Box
          as="form"
          action={action}
          method="POST"
          style={{
            flex: 1,
            padding: '48px 40px',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'center',
          }}
        >
          <H5 style={{ marginBottom: 32, color: '#1A1A1A', fontSize: 20 }}>
            {branding.companyName}
          </H5>

          {message && (
            <MessageBox
              my="lg"
              message={message.split(' ').length > 1 ? message : translateMessage(message)}
              variant="danger"
            />
          )}

          <FormGroup>
            <Label required>
              {translateComponent('Login.loginLabel', { defaultValue: 'Email' })}
            </Label>
            <Input
              name="email"
              placeholder={translateComponent('Login.loginLabel', { defaultValue: 'Email' })}
            />
          </FormGroup>

          <FormGroup>
            <Label required>
              {translateComponent('Login.passwordLabel', { defaultValue: 'Password' })}
            </Label>
            <Input
              type="password"
              name="password"
              placeholder={translateComponent('Login.passwordLabel', { defaultValue: 'Password' })}
              autoComplete="new-password"
            />
          </FormGroup>

          <Text mt="xl" textAlign="center">
            <Button variant="contained" style={{ width: '100%', borderRadius: 24 }}>
              {translateComponent('Login.loginButton')}
            </Button>
          </Text>
        </Box>
      </Box>

      <style>{`
        @media (max-width: 680px) {
          .login__left-panel { display: none !important; }
        }
      `}</style>
    </Box>
  );
};

export default Login;
