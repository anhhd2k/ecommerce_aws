const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: 'ap-southeast-1_X4cv4NGD8', // e.g., ap-south-1_xxxxxxxxx
      userPoolClientId: '47pv081osobk41k7ua4m4la114', // e.g., 1a2b3c4d5e6f7g8h9i0j1k2l3m
      loginWith: {
        email: true,
      },
    }
  },
  API: {
    baseUrl: 'https://nightmare.io' // e.g., https://xxxxxxxxxx.execute-api.ap-south-1.amazonaws.com
  }
};

export default awsConfig;
