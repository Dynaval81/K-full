const axios = require('axios');

// Для продакшена используем localhost (внутри сервера)
const MATRIX_HOMESERVER_URL = 'http://localhost:8008';
const MATRIX_DOMAIN = 'hypermax.duckdns.org';
const MATRIX_ADMIN_TOKEN = process.env.MATRIX_ADMIN_TOKEN;

// Создание пользователя в Matrix
exports.createUser = async (email, password, username, vtNumber) => {
  try {
    // Генерируем Matrix username с префиксом v (например: @v12345:hypermax.duckdns.org)
    const numericPart = vtNumber.replace('VT-', ''); // Убираем префикс VT-
    const matrixUsername = `v${numericPart}`; // Добавляем префикс v

    console.log(`Creating Matrix user: @${matrixUsername}:${MATRIX_DOMAIN} for ${email}`);

    // Создаем пользователя через Matrix Admin API (PUT метод!)
    const response = await axios.put(
      `${MATRIX_HOMESERVER_URL}/_synapse/admin/v2/users/@${matrixUsername}:${MATRIX_DOMAIN}`,
      {
        password: password,
        displayname: username, // Используем переданный username
        admin: false
      },
      {
        headers: {
          'Authorization': `Bearer ${MATRIX_ADMIN_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('✅ Matrix user created:', response.data.name);

    // Получаем access token для пользователя
    const loginResponse = await axios.post(
      `${MATRIX_HOMESERVER_URL}/_matrix/client/r0/login`,
      {
        type: 'm.login.password',
        user: matrixUsername,
        password: password
      },
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    return {
      success: true,
      userId: response.data.name,
      accessToken: loginResponse.data.access_token
    };
  } catch (error) {
    console.error('❌ Matrix user creation failed:', error.response?.data || error.message);
    return {
      success: false,
      error: error.response?.data?.error || error.message
    };
  }
};
