import React, { useState, useMemo } from 'react';
import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  View,
  TextInput,
  Pressable,
  KeyboardAvoidingView,
  Platform,
  Alert,
  ActivityIndicator,
  useColorScheme,
  Image,
} from 'react-native';
import { Theme } from './src/Theme';
import { useUUIDValidation } from './src/hooks';
import { scanQRCode, startRequest, isMiVIPError } from '@mitek/react-native-mivip';

const App = () => {
  const isDarkMode = useColorScheme() === 'dark';
  const colors = isDarkMode ? Theme.dark : Theme.light;

  const [requestId, setRequestId] = useState('');
  const [loading, setLoading] = useState(false);
  const { trimmedValue, isValid } = useUUIDValidation(requestId);

  const handleScanQR = async () => {
    try {
      setLoading(true);
      const result = await scanQRCode();
      Alert.alert('Success', `Verification Result: ${result}`);
    } catch (error) {
      if (isMiVIPError(error)) {
        Alert.alert(
          error.recoverable ? 'Please Try Again' : 'Error',
          error.userMessage
        );
      } else {
        Alert.alert('Error', 'An unexpected error occurred');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleManualEntry = async () => {
    if (!isValid) {
      Alert.alert('Validation Error', 'Please enter a valid Request ID (UUID format).');
      return;
    }

    try {
      setLoading(true);
      const result = await startRequest(trimmedValue);
      Alert.alert('Success', `Verification Result: ${result}`);
    } catch (error) {
      if (isMiVIPError(error)) {
        Alert.alert(
          error.recoverable ? 'Please Try Again' : 'Error',
          error.userMessage
        );
      } else {
        Alert.alert('Error', 'An unexpected error occurred');
      }
    } finally {
      setLoading(false);
    }
  };

  const dynamicStyles = useMemo(() => StyleSheet.create({
    container: {
      backgroundColor: colors.background,
    },
    title: {
      color: isDarkMode ? colors.white : colors.mitekRed,
    },
    subtitle: {
      color: colors.secondaryText,
    },
    card: {
      backgroundColor: colors.secondaryBackground,
    },
    cardTitle: {
      color: colors.text,
    },
    cardDescription: {
      color: colors.secondaryText,
    },
    divider: {
      color: colors.secondaryText,
    },
    input: {
      backgroundColor: colors.inputBackground,
      color: colors.text,
      borderColor: colors.inputBorder,
    },
    logoText: {
      color: isDarkMode ? colors.white : colors.mitekBlue,
    }
  }), [isDarkMode, colors]);

  return (
    <SafeAreaView style={[styles.container, dynamicStyles.container]}>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.flex}
      >
        <ScrollView contentContainerStyle={styles.scrollContent}>
          <View style={styles.logoContainer}>
            <Image 
              source={require('./src/assets/mitek_logo.png')} 
              style={[styles.logoImage, isDarkMode && { tintColor: colors.white }]} 
              resizeMode="contain" 
            />
          </View>

          <Text style={[styles.title, dynamicStyles.title]}>Identity Verification</Text>
          <Text style={[styles.subtitle, dynamicStyles.subtitle]}>
            Complete your verification journey using one of the options below.
          </Text>

          {/* QR Card */}
          <View style={[styles.card, dynamicStyles.card]}>
            <View style={styles.cardHeader}>
              <Text style={styles.cardIcon}>📷</Text>
              <Text style={[styles.cardTitle, dynamicStyles.cardTitle]}>Scan QR Code</Text>
            </View>
            <Text style={[styles.cardDescription, dynamicStyles.cardDescription]}>
              Scan the QR code from your email or verification portal.
            </Text>
            <Pressable
              style={({ pressed }) => [
                styles.primaryButton,
                pressed && styles.buttonPressed,
                loading && styles.disabledButton,
              ]}
              onPress={handleScanQR}
              disabled={loading}
              accessibilityRole="button"
              accessibilityLabel="Scan QR code to start verification"
            >
              <Text style={styles.buttonText}>Scan QR</Text>
            </Pressable>
          </View>

          <Text style={[styles.divider, dynamicStyles.divider]}>— OR —</Text>

          {/* Manual Entry Card */}
          <View style={[styles.card, dynamicStyles.card]}>
            <View style={styles.cardHeader}>
              <Text style={styles.cardIcon}>🔑</Text>
              <Text style={[styles.cardTitle, dynamicStyles.cardTitle]}>Enter Request ID</Text>
            </View>
            <Text style={[styles.cardDescription, dynamicStyles.cardDescription]}>
              Manually enter your verification Request ID.
            </Text>
            <TextInput
              style={[
                styles.input,
                dynamicStyles.input,
                requestId.length > 0 && {
                  borderColor: isValid ? 'green' : colors.mitekRed,
                },
              ]}
              placeholder="Enter ID"
              placeholderTextColor={colors.secondaryText}
              value={requestId}
              onChangeText={setRequestId}
              autoCapitalize="none"
              autoCorrect={false}
            />
            <Pressable
              style={({ pressed }) => [
                styles.primaryButton,
                pressed && styles.buttonPressed,
                (!isValid || loading) && styles.disabledButton,
              ]}
              onPress={handleManualEntry}
              disabled={!isValid || loading}
              accessibilityRole="button"
              accessibilityLabel="Submit request ID to start verification"
            >
              <Text style={styles.buttonText}>Continue</Text>
            </Pressable>
          </View>

          {loading && (
            <ActivityIndicator
              size="large"
              color={colors.mitekRed}
              style={styles.loader}
            />
          )}
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  flex: {
    flex: 1,
  },
  scrollContent: {
    padding: Theme.spacing.l,
    alignItems: 'center',
  },
  logoContainer: {
    height: 60,
    justifyContent: 'center',
    marginBottom: Theme.spacing.l,
  },
  logoImage: {
    width: 200,
    height: 60,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: Theme.spacing.s,
  },
  subtitle: {
    fontSize: 16,
    textAlign: 'center',
    marginBottom: Theme.spacing.xl,
  },
  card: {
    width: '100%',
    borderRadius: Theme.borderRadius.l,
    padding: Theme.spacing.l,
    marginBottom: Theme.spacing.m,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Theme.spacing.m,
    marginBottom: Theme.spacing.m,
  },
  cardIcon: {
    fontSize: 24,
  },
  cardTitle: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  cardDescription: {
    fontSize: 14,
    marginBottom: Theme.spacing.l,
  },
  primaryButton: {
    backgroundColor: '#EE2C46', // Always Red
    borderRadius: Theme.borderRadius.m,
    height: 50,
    justifyContent: 'center',
    alignItems: 'center',
  },
  disabledButton: {
    backgroundColor: '#CCCCCC',
  },
  buttonPressed: {
    opacity: 0.8,
    transform: [{ scale: 0.98 }],
  },
  buttonText: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: 'bold',
  },
  divider: {
    marginVertical: Theme.spacing.m,
  },
  input: {
    borderWidth: 1,
    borderRadius: Theme.borderRadius.m,
    padding: Theme.spacing.m,
    marginBottom: Theme.spacing.l,
    fontSize: 16,
  },
  loader: {
    marginTop: Theme.spacing.l,
  },
});

export default App;
